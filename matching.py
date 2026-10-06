from datetime import date
import math
from database import get_connection


# =========================================================
# 1. CALCULATE DISTANCE
# =========================================================
def calculate_distance(lat1, lon1, lat2, lon2):

    # Radius of Earth in kilometers
    R = 6371

    lat1 = math.radians(float(lat1))
    lon1 = math.radians(float(lon1))
    lat2 = math.radians(float(lat2))
    lon2 = math.radians(float(lon2))

    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1)
        * math.cos(lat2)
        * math.sin(dlon / 2) ** 2
    )

    c = 2 * math.atan2(
        math.sqrt(a),
        math.sqrt(1 - a)
    )

    return round(R * c, 2)


# =========================================================
# 2. CHECK DONOR ELIGIBILITY
# =========================================================
def is_donor_eligible(gender, last_donation_date):

    # Donor has never donated
    if last_donation_date is None:
        return True

    today = date.today()

    # SQL Server may return datetime
    if hasattr(last_donation_date, "date"):
        last_donation_date = last_donation_date.date()

    days_since_donation = (
        today - last_donation_date
    ).days

    # Donation waiting period
    if gender.lower() == "male":
        required_gap = 90

    elif gender.lower() == "female":
        required_gap = 120

    else:
        return False

    return days_since_donation >= required_gap


# =========================================================
# 3. BLOOD GROUP COMPATIBILITY
# =========================================================
def is_blood_compatible(donor_blood, required_blood):

    compatibility = {

        "O-": [
            "O-"
        ],

        "O+": [
            "O-",
            "O+"
        ],

        "A-": [
            "O-",
            "A-"
        ],

        "A+": [
            "O-",
            "O+",
            "A-",
            "A+"
        ],

        "B-": [
            "O-",
            "B-"
        ],

        "B+": [
            "O-",
            "O+",
            "B-",
            "B+"
        ],

        "AB-": [
            "O-",
            "A-",
            "B-",
            "AB-"
        ],

        "AB+": [
            "O-",
            "O+",
            "A-",
            "A+",
            "B-",
            "B+",
            "AB-",
            "AB+"
        ]
    }

    return donor_blood in compatibility.get(
        required_blood,
        []
    )


# =========================================================
# 4. URGENCY BONUS
# =========================================================
def get_urgency_bonus(urgency):

    if urgency is None:
        return 0

    urgency = urgency.lower()

    if urgency == "critical":
        return 30

    elif urgency == "high":
        return 15

    elif urgency == "normal":
        return 0

    return 0


# =========================================================
# 5. FIND MATCHING DONORS
# =========================================================
def find_matching_donors(
    donors,
    required_blood,
    hospital_latitude,
    hospital_longitude,
    urgency
):

    matches = []

    # Calculate urgency bonus
    urgency_bonus = get_urgency_bonus(urgency)

    for donor in donors:

        # -------------------------------------------------
        # Check blood compatibility
        # -------------------------------------------------
        if not is_blood_compatible(
            donor["BloodGroup"],
            required_blood
        ):
            continue

        # -------------------------------------------------
        # Check donation eligibility
        # -------------------------------------------------
        if not is_donor_eligible(
            donor["Gender"],
            donor["LastDonationDate"]
        ):
            continue

        # -------------------------------------------------
        # Check donor location
        # -------------------------------------------------
        if (
            donor["Latitude"] is None
            or donor["Longitude"] is None
        ):
            continue

        # -------------------------------------------------
        # Calculate distance
        # -------------------------------------------------
        distance = calculate_distance(
            hospital_latitude,
            hospital_longitude,
            donor["Latitude"],
            donor["Longitude"]
        )

        # -------------------------------------------------
        # Calculate distance score
        # -------------------------------------------------
        distance_score = 100 / (
            1 + distance
        )

        # -------------------------------------------------
        # Calculate final match score
        # -------------------------------------------------
        match_score = (
            distance_score
            + urgency_bonus
        )

        match_score = round(
            min(match_score, 100),
            2
        )

        matches.append({

            "DonorID": donor["DonorID"],
            "FullName": donor["FullName"],
            "Gender": donor["Gender"],
            "BloodGroup": donor["BloodGroup"],
            "Phone": donor["Phone"],
            "Email": donor["Email"],
            "City": donor["City"],
            "Latitude": donor["Latitude"],
            "Longitude": donor["Longitude"],
            "LastDonationDate": donor["LastDonationDate"],
            "DistanceKM": distance,
            "MatchScore": match_score

        })

    # -----------------------------------------------------
    # Sort by highest match score
    # -----------------------------------------------------
    matches.sort(
        key=lambda x: x["MatchScore"],
        reverse=True
    )

    return matches


# =========================================================
# 6. SAVE MATCHES + CREATE NOTIFICATIONS
# =========================================================
def save_matches(
    request_id,
    matches,
    required_blood,
    urgency
):

    connection = get_connection()
    cursor = connection.cursor()

    try:

        # -------------------------------------------------
        # Remove notifications belonging to old matches
        # -------------------------------------------------
        cursor.execute(
            """
            DELETE FROM Notifications
            WHERE MatchID IN
            (
                SELECT MatchID
                FROM DonorMatches
                WHERE RequestID = ?
            )
            """,
            (request_id,)
        )

        # -------------------------------------------------
        # Remove old matches
        # -------------------------------------------------
        cursor.execute(
            """
            DELETE FROM DonorMatches
            WHERE RequestID = ?
            """,
            (request_id,)
        )

        # -------------------------------------------------
        # Insert new matches
        # -------------------------------------------------
        for donor in matches:

            match_query = """
            INSERT INTO DonorMatches
            (
                RequestID,
                DonorID,
                DistanceKM,
                MatchScore,
                MatchStatus
            )
            OUTPUT INSERTED.MatchID
            VALUES (?, ?, ?, ?, ?)
            """

            cursor.execute(
                match_query,
                (
                    request_id,
                    donor["DonorID"],
                    donor["DistanceKM"],
                    donor["MatchScore"],
                    "Matched"
                )
            )

            result = cursor.fetchone()

            if result is None:
                raise Exception(
                    "Could not get MatchID."
                )

            match_id = int(result[0])

            # -------------------------------------------------
            # Create notification message
            # -------------------------------------------------
            if urgency.lower() == "critical":

                message = (
                    f"Emergency blood request for "
                    f"{required_blood}. "
                    f"Please respond as soon as possible."
                )

            elif urgency.lower() == "high":

                message = (
                    f"Urgent blood request for "
                    f"{required_blood}. "
                    f"Please respond if you are available."
                )

            else:

                message = (
                    f"Blood request for "
                    f"{required_blood}. "
                    f"Please respond if you are available."
                )

            # -------------------------------------------------
            # Notification type
            # Database allows only Email or SMS
            # -------------------------------------------------
            notification_type = "SMS"

            # -------------------------------------------------
            # Insert notification
            # -------------------------------------------------
            notification_query = """
            INSERT INTO Notifications
            (
                MatchID,
                DonorID,
                Message,
                NotificationType,
                SentAt,
                DeliveryStatus
            )
            VALUES (?, ?, ?, ?, GETDATE(), ?)
            """

            cursor.execute(
                notification_query,
                (
                    match_id,
                    donor["DonorID"],
                    message,
                    notification_type,
                    "Sent"
                )
            )

        connection.commit()

        print(
            f"{len(matches)} MATCHES SAVED SUCCESSFULLY "
            f"FOR REQUEST {request_id}"
        )

        print(
            f"{len(matches)} NOTIFICATIONS CREATED "
            f"FOR REQUEST {request_id}"
        )

    except Exception:

        connection.rollback()
        raise

    finally:

        cursor.close()
        connection.close()


# =========================================================
# 7. AUTOMATIC MATCHING FOR BLOOD REQUEST
# =========================================================
def match_blood_request(request_id):

    connection = get_connection()
    cursor = connection.cursor()

    # -----------------------------------------------------
    # Get blood request information
    # -----------------------------------------------------
    cursor.execute(
        """
        SELECT
            BloodGroup,
            HospitalID,
            Urgency,
            UnitsRequired
        FROM BloodRequests
        WHERE RequestID = ?
        """,
        (request_id,)
    )

    request_data = cursor.fetchone()

    if not request_data:

        cursor.close()
        connection.close()

        print(
            f"Request {request_id} not found."
        )

        return []

    required_blood = request_data[0]
    hospital_id = request_data[1]
    urgency = request_data[2]
    units_required = request_data[3]

    # -----------------------------------------------------
    # Validate UnitsRequired
    # -----------------------------------------------------
    if units_required is None or units_required <= 0:

        cursor.close()
        connection.close()

        print(
            f"Invalid UnitsRequired for Request {request_id}"
        )

        return []

    # -----------------------------------------------------
    # Get hospital location
    # -----------------------------------------------------
    cursor.execute(
        """
        SELECT
            Latitude,
            Longitude
        FROM Hospitals
        WHERE HospitalID = ?
        """,
        (hospital_id,)
    )

    hospital = cursor.fetchone()

    if not hospital:

        cursor.close()
        connection.close()

        print(
            f"Hospital {hospital_id} not found."
        )

        return []

    hospital_latitude = hospital[0]
    hospital_longitude = hospital[1]

    # -----------------------------------------------------
    # Get all donors
    # -----------------------------------------------------
    cursor.execute(
        """
        SELECT
            DonorID,
            FullName,
            Gender,
            BloodGroup,
            Phone,
            Email,
            City,
            Latitude,
            Longitude,
            LastDonationDate
        FROM Donors
        """
    )

    rows = cursor.fetchall()

    donors = []

    for row in rows:

        donors.append({

            "DonorID": row[0],
            "FullName": row[1],
            "Gender": row[2],
            "BloodGroup": row[3],
            "Phone": row[4],
            "Email": row[5],
            "City": row[6],
            "Latitude": row[7],
            "Longitude": row[8],
            "LastDonationDate": row[9]

        })

    cursor.close()
    connection.close()

    # -----------------------------------------------------
    # Find all eligible + compatible donors
    # -----------------------------------------------------
    matches = find_matching_donors(
        donors,
        required_blood,
        hospital_latitude,
        hospital_longitude,
        urgency
    )

    # -----------------------------------------------------
    # Select priority donors
    # -----------------------------------------------------
    selected_matches = matches[:units_required]

    # -----------------------------------------------------
    # Save matches + notifications
    # -----------------------------------------------------
    if selected_matches:

        save_matches(
            request_id,
            selected_matches,
            required_blood,
            urgency
        )

        print(
            f"{len(selected_matches)} PRIORITY DONORS "
            f"SELECTED FOR REQUEST {request_id}"
        )

    else:

        print(
            f"No matching donors found "
            f"for Request {request_id}"
        )

    return selected_matches
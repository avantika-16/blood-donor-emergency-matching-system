from flask import Flask, render_template, request, redirect, url_for
from matching import match_blood_request
from database import get_connection

app = Flask(__name__)


# =========================
# HOME PAGE
# =========================
@app.route("/")
def index():
    return render_template("index.html")


# =========================
# DONOR REGISTRATION
# =========================
@app.route("/donor/register", methods=["GET", "POST"])
def donor_register():

    if request.method == "POST":

        full_name = request.form["full_name"]
        gender = request.form["gender"]
        blood_group = request.form["blood_group"]
        phone = request.form["phone"]
        email = request.form["email"]
        city = request.form["city"]
        latitude = request.form["latitude"]
        longitude = request.form["longitude"]
        last_donation_date = request.form["last_donation_date"]

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO Donors
            (
                FullName,
                Gender,
                BloodGroup,
                Phone,
                Email,
                City,
                Latitude,
                Longitude,
                LastDonationDate
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            full_name,
            gender,
            blood_group,
            phone,
            email,
            city,
            latitude,
            longitude,
            last_donation_date
        ))

        conn.commit()
        conn.close()

        return redirect(url_for("index"))

    return render_template("donor_register.html")


# =========================
# HOSPITAL REGISTRATION
# =========================
@app.route("/hospital/register", methods=["GET", "POST"])
def hospital_register():

    if request.method == "POST":

        hospital_name = request.form["hospital_name"]
        contact_person = request.form["contact_person"]
        phone = request.form["phone"]
        email = request.form["email"]
        city = request.form["city"]
        address = request.form["address"]
        latitude = request.form["latitude"]
        longitude = request.form["longitude"]

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO Hospitals
            (
                HospitalName,
                ContactPerson,
                Phone,
                Email,
                City,
                Address,
                Latitude,
                Longitude
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            hospital_name,
            contact_person,
            phone,
            email,
            city,
            address,
            latitude,
            longitude
        ))

        conn.commit()
        conn.close()

        return redirect(url_for("index"))

    return render_template("hospital_register.html")


# =========================
# BLOOD REQUEST
# =========================
@app.route("/request/blood", methods=["GET", "POST"])
def blood_request():

    if request.method == "POST":

        hospital_id = request.form["hospital_id"]
        blood_group = request.form["blood_group"]
        units_required = request.form["units_required"]
        urgency = request.form["urgency"]
        required_date = request.form["required_date"]

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO BloodRequests
            (
                HospitalID,
                BloodGroup,
                UnitsRequired,
                Urgency,
                RequiredDate,
                Status
            )
            OUTPUT INSERTED.RequestID
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            hospital_id,
            blood_group,
            units_required,
            urgency,
            required_date,
            "Open"
        ))

        request_id = cursor.fetchone()[0]

        conn.commit()
        conn.close()

        # Automatically find matching donors
        match_blood_request(request_id)

        return redirect(url_for(
            "matches",
            request_id=request_id
        ))

    return render_template("blood_request.html")


# =========================
# SHOW MATCHED DONORS
# =========================
@app.route("/matches/<int:request_id>")
def matches(request_id):

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            dm.MatchID,
            dm.RequestID,
            dm.DonorID,
            d.FullName,
            d.BloodGroup,
            d.Phone,
            d.Email,
            d.City,
            dm.DistanceKM,
            dm.MatchScore,
            dm.MatchStatus
        FROM DonorMatches dm
        INNER JOIN Donors d
            ON dm.DonorID = d.DonorID
        WHERE dm.RequestID = ?
        ORDER BY
            dm.MatchScore DESC,
            dm.DistanceKM ASC
    """, (request_id,))

    matches_data = cursor.fetchall()

    conn.close()

    return render_template(
        "matches.html",
        matches=matches_data,
        request_id=request_id
    )


# =========================
# DONOR NOTIFICATIONS
# =========================
@app.route("/donor/<int:donor_id>/notifications")
def donor_notifications(donor_id):

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            n.NotificationID,
            n.MatchID,
            n.DonorID,
            n.Message,
            n.NotificationType,
            n.SentAt,
            n.DeliveryStatus,

            br.BloodGroup,
            br.UnitsRequired,
            br.Urgency,
            br.RequiredDate,
            br.RequestID,

            dm.MatchStatus

        FROM Notifications n

        INNER JOIN DonorMatches dm
            ON n.MatchID = dm.MatchID

        INNER JOIN BloodRequests br
            ON dm.RequestID = br.RequestID

        WHERE n.DonorID = ?

        ORDER BY n.SentAt DESC
    """, (donor_id,))

    notifications = cursor.fetchall()

    conn.close()

    return render_template(
        "donor_notifications.html",
        notifications=notifications,
        donor_id=donor_id
    )


# =========================
# ACCEPT / DECLINE MATCH
# =========================
@app.route("/match/<int:match_id>/response", methods=["POST"])
def match_response(match_id):

    response = request.form.get("response")

    # Allow only valid responses
    if response not in ["Accepted", "Declined"]:
        return "Invalid response", 400

    conn = get_connection()
    cursor = conn.cursor()

    # Find donor associated with this match
    cursor.execute("""
        SELECT DonorID
        FROM DonorMatches
        WHERE MatchID = ?
    """, (match_id,))

    row = cursor.fetchone()

    if not row:
        conn.close()
        return "Match not found", 404

    donor_id = row[0]

    # Update match status
    cursor.execute("""
        UPDATE DonorMatches
        SET MatchStatus = ?
        WHERE MatchID = ?
    """, (
        response,
        match_id
    ))

    conn.commit()
    conn.close()

    # Return donor to notification page
    return redirect(url_for(
        "donor_notifications",
        donor_id=donor_id
    ))


# =========================
# HOSPITAL DASHBOARD
# =========================
@app.route("/hospital/dashboard")
def hospital_dashboard():

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            br.RequestID,
            br.HospitalID,
            br.BloodGroup,
            br.UnitsRequired,
            br.Urgency,
            br.RequiredDate,
            br.Status,
            br.CreatedAt,

            dm.MatchID,
            dm.DonorID,
            d.FullName,
            d.Phone,
            d.Email,
            d.City,
            dm.DistanceKM,
            dm.MatchScore,
            dm.MatchStatus

        FROM BloodRequests br

        LEFT JOIN DonorMatches dm
            ON br.RequestID = dm.RequestID

        LEFT JOIN Donors d
            ON dm.DonorID = d.DonorID

        ORDER BY
            br.CreatedAt DESC,
            dm.MatchScore DESC
    """)

    rows = cursor.fetchall()

    conn.close()

    return render_template(
        "hospital_dashboard.html",
        requests=rows
    )

# =========================
# RUN APPLICATION
# =========================
if __name__ == "__main__":
    app.run(debug=True)
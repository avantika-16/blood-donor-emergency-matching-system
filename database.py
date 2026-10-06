import pyodbc


def get_connection():
    connection = pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"
        "DATABASE=BloodDonorSystem;"
        "Trusted_Connection=yes;"
    )

    return connection
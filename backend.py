from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Depends
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session
import shutil
import os

# 1. Database Configuration
DATABASE_URL = "mysql+pymysql://username:password@localhost/university_booking"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

app = FastAPI()

# Ensure directory for PDFs exists
UPLOAD_DIR = "uploaded_pdfs"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 2. The Booking Endpoint
@app.post("/book-room/")
async def create_booking(
    user_id: int = Form(...),
    classroom_id: int = Form(...),
    date: str = Form(...),
    start_time: str = Form(...),
    end_time: str = Form(...),
    people_count: int = Form(...),
    pdf_file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    # STEP 1: Conflict Detection (FIXED: Using text() and parameter binding)
    conflict_query = text("""
        SELECT 1 FROM bookings 
        WHERE classroom_id = :c_id 
        AND booking_date = :date
        AND status = 'confirmed'
        AND (:s_time < end_time AND :e_time > start_time)
    """)
    
    conflict = db.execute(conflict_query, {
        "c_id": classroom_id,
        "date": date,
        "s_time": start_time,
        "e_time": end_time
    }).fetchone()

    if conflict:
        raise HTTPException(status_code=400, detail="Room is already booked for this time slot.")

    # STEP 2: Save the PDF File
    file_path = os.path.join(UPLOAD_DIR, f"{user_id}_{classroom_id}_{date}_{pdf_file.filename}")
    
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(pdf_file.file, buffer)

        # STEP 3: Insert into Database (FIXED: Wrapped in try block + using parameters)
        insert_query = text("""
            INSERT INTO bookings (user_id, classroom_id, booking_date, start_time, end_time, expected_attendees, pdf_attachment_path, status)
            VALUES (:u_id, :c_id, :date, :s_time, :e_time, :count, :path, 'confirmed')
        """)
        
        db.execute(insert_query, {
            "u_id": user_id, 
            "c_id": classroom_id, 
            "date": date, 
            "s_time": start_time, 
            "e_time": end_time, 
            "count": people_count, 
            "path": file_path
        })
        db.commit()

    except Exception as e:
        # CLEANUP: If DB fails, delete the file we just uploaded
        if os.path.exists(file_path):
            os.remove(file_path)
        print(f"Error: {e}") # Log the error for debugging
        raise HTTPException(status_code=500, detail="Database error. Booking failed.")

    return {"message": "Booking successful!", "file_saved_at": file_path}

# 3. Get Schedule Endpoint
@app.get("/schedule/{classroom_id}/{date}")
def get_schedule(classroom_id: int, date: str, db: Session = Depends(get_db)):
    # FIXED: Using text() and parameter binding
    query = text("""
        SELECT start_time, end_time 
        FROM bookings 
        WHERE classroom_id = :c_id 
        AND booking_date = :date 
        AND status = 'confirmed'
    """)
    
    results = db.execute(query, {"c_id": classroom_id, "date": date}).fetchall()
    
    return [{"start": str(r[0]), "end": str(r[1])} for r in results]
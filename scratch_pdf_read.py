import os
from pypdf import PdfReader

try:
    reader = PdfReader("c:/Users/LYK20/HW_Music/1.pdf")
    text = ""
    for page in reader.pages:
        text += page.extract_text() + "\n"
        
    with open("c:/Users/LYK20/HW_Music/1_pdf_content.txt", "w", encoding="utf-8") as f:
        f.write(text)
    print("Successfully extracted text to 1_pdf_content.txt")
except Exception as e:
    print(f"Error: {e}")

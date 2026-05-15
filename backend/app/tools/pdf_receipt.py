from reportlab.lib.pagesizes import A5
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
from reportlab.lib import colors
from datetime import datetime
import os

def generate_receipt(booking_id: str, intent, provider, accepted_quote, user_name: str = None) -> str:
    """
    Generate an A5 portrait PDF receipt for a booking.
    Returns the file path.
    """
    filename = f"receipt_{booking_id}.pdf"
    output_dir = "static/receipts"
    os.makedirs(output_dir, exist_ok=True)
    filepath = os.path.join(output_dir, filename)
    
    c = canvas.Canvas(filepath, pagesize=A5)
    width, height = A5
    
    # ZONE 1: Header
    c.setFont("Helvetica-Bold", 22)
    c.setFillColor(colors.HexColor("#1a1d29"))
    c.drawString(12*mm, height - 20*mm, "Bulao.")
    
    c.setFont("Helvetica-Bold", 9)
    c.setFillColor(colors.HexColor("#b8860b"))
    c.drawRightString(width - 12*mm, height - 20*mm, "RASEED")
    
    c.setStrokeColor(colors.HexColor("#1a1d29"))
    c.setLineWidth(0.8)
    c.line(12*mm, height - 24*mm, width - 12*mm, height - 24*mm)
    
    # ZONE 2: Booking ID row
    c.setFont("Courier", 11)
    c.setFillColor(colors.HexColor("#4a5568")) # Slate
    c.drawString(12*mm, height - 35*mm, f"ID: {booking_id}")
    
    # Badge (simplified)
    c.setFillColor(colors.HexColor("#b8860b"))
    c.roundRect(width - 45*mm, height - 37*mm, 33*mm, 6*mm, 2, fill=1)
    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 8)
    c.drawCentredString(width - 28.5*mm, height - 34*mm, "CONFIRM HO GAYA")
    
    # ZONE 3: Provider block
    c.setFont("Helvetica-Bold", 14)
    c.setFillColor(colors.HexColor("#1a202c")) # Ink
    c.drawString(12*mm, height - 55*mm, provider.name)
    
    c.setFont("Helvetica", 10)
    c.setFillColor(colors.HexColor("#4a5568"))
    c.drawString(12*mm, height - 62*mm, f"{provider.rating} Rating | {provider.years_experience} Years Exp")
    c.drawString(12*mm, height - 68*mm, f"{provider.neighborhood}, {intent.city}")
    
    # ZONE 4: Service details
    c.setFont("Helvetica-Bold", 11)
    c.drawString(12*mm, height - 85*mm, "Service Details")
    c.setFont("Helvetica", 10)
    c.drawString(12*mm, height - 92*mm, f"Type: {intent.service_type.replace('_', ' ').title()}")
    c.drawString(12*mm, height - 98*mm, f"Time: {accepted_quote.expires_at}") # Use a better time representation in real app
    
    # ZONE 5: Price breakdown
    c.setFont("Helvetica-Bold", 11)
    c.drawString(12*mm, height - 120*mm, "Hisab-e-Khidmat (Price Breakdown)")
    
    curr_y = height - 130*mm
    for item in accepted_quote.line_items:
        c.setFont("Helvetica", 10)
        c.drawString(15*mm, curr_y, f"{item.label_english} ({item.label_urdu})")
        c.drawRightString(width - 15*mm, curr_y, f"PKR {item.amount_pkr:,}")
        curr_y -= 6*mm
        
    c.setLineWidth(0.5)
    c.line(15*mm, curr_y + 2*mm, width - 15*mm, curr_y + 2*mm)
    
    c.setFont("Helvetica-Bold", 12)
    c.drawString(15*mm, curr_y - 4*mm, "Total")
    c.drawRightString(width - 15*mm, curr_y - 4*mm, f"PKR {accepted_quote.estimated_total_pkr:,}")
    
    # ZONE 6: Transparency
    c.setFont("Helvetica-Oblique", 9)
    c.setFillColor(colors.HexColor("#718096")) # Mute
    c.drawString(12*mm, curr_y - 15*mm, f"Provider ko milenge PKR {int(accepted_quote.estimated_total_pkr * 0.85):,} platform fee ke baad")
    
    # ZONE 7: QR Code placeholder (square with caption)
    c.setStrokeColor(colors.lightgrey)
    c.rect(width/2 - 15*mm, 25*mm, 30*mm, 30*mm)
    c.setFont("Helvetica", 8)
    c.drawCentredString(width/2, 21*mm, "Booking track karein")
    
    # ZONE 8: Footer
    c.setFont("Helvetica-BoldOblique", 8)
    c.setFillColor(colors.HexColor("#b8860b"))
    c.drawCentredString(width/2, 10*mm, "Bulao \u2014 Bolo, aur kaam ho jaye.")
    
    c.save()
    return filepath

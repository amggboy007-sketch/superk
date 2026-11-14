# Super K

ระบบจัดการร้านค้าและคลังสินค้าหลายสาขา พัฒนาเป็นเว็บแอปแบบ Mobile-first โดยใช้ Supabase เป็น Backend

## โครงสร้าง
- `index.html` — Frontend
- `supabase/migrations/` — โครงสร้างฐานข้อมูลและนโยบาย RLS
- `supabase/functions/chat-cleanup/` — Edge Function สำหรับลบไฟล์แชทที่หมดอายุ

## สถานะ
กำลังเตรียมอัปโหลด source code และเชื่อมต่อกับ Supabase โปรดอย่านำขึ้นใช้งานจริงจนกว่าจะตั้งค่า secrets, schedule งาน cleanup และทดสอบการทำงานครบถ้วน

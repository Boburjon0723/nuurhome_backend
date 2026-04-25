-- Demo: 10 ta bir-biriga o'xshamaydigan sharh (birinchi faol mahsulot uchun).
-- Supabase → SQL Editor → barchasini ishga tushiring.
-- Eslatma: user_id NULL — agar jadval NOT NULL talab qilsa, pastdagi SELECT orqali mavjud user UUID qo'ying.

INSERT INTO reviews (product_id, user_id, rating, comment, status)
SELECT
  (SELECT id FROM products WHERE is_active IS NOT FALSE ORDER BY created_at DESC NULLS LAST LIMIT 1),
  NULL::uuid,
  v.rating,
  v.comment,
  'approved'
FROM (VALUES
  (5, 'Uydan chiqmay turib buyurtma qildim. Qadoq va sifat zo‘r, rangi saytdagi rasmdan farq qilmaydi.'),
  (4, 'Kuryer biroz kechikdi, lekin operatorlar oldindan ogohlantirishdi. Mahsulotga narxi mos.'),
  (5, 'Interyerga aynan shu detal yetishib qolgan edi — endi xona boshqacha ko‘rinadi. Katta rahmat!'),
  (3, 'Kutilganidan kichikroq tuyuldi. Oldin o‘lchamlarni yana bir bor tekshirib oling degan maslahat.'),
  (5, 'Onamga sovg‘a qildim, juda xursand. Sifat va dizayn ikkalasi ham yoqdi.'),
  (4, 'Narxi va sifat nisbati yaxshi. Uzoq muddatli foydalanishni ko‘raman.'),
  (5, 'Savollarimga tez javob berishdi. Ishonch bilan yana buyurtma beraman.'),
  (4, 'Rang tanlashda ikkilanib qolgandim, maslahatchi yordamida to‘g‘ri tanladim. Natija chiroyli.'),
  (5, 'Ikkinchi marta buyurtma — birinchi safar ham shunday qoniqarli edi.'),
  (5, 'Butunlay sokin rang, devorga mos keldi. Yig‘ilish sifati ham yuqori.')
) AS v(rating, comment)
WHERE EXISTS (SELECT 1 FROM products LIMIT 1);

-- Agar INSERT user_id tufayli xato bersa, avval mavjud foydalanuvchi id sini oling:
-- SELECT id FROM auth.users LIMIT 1;
-- Keyin NULL o‘rniga shu UUID ni qo‘ying (masalan, bir nechta INSERT uchun).

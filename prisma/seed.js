const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function main() {
  const hashedPassword = await bcrypt.hash('admin123', 10);
  
  const admin = await prisma.user.upsert({
    where: { email: 'admin@nuurhome.uz' },
    update: {},
    create: {
      email: 'admin@nuurhome.uz',
      password: hashedPassword,
      fullname: 'Administrator',
      role: 'ADMIN'
    }
  });

  console.log('Seed: Admin yaratildi/yangilandi', admin.email);

  // Default Settings
  const defaultSettings = [
    { key: 'site_name', value: 'Nuur Home' },
    { key: 'phone', value: '+998 90 123 45 67' },
    { key: 'email', value: 'info@nuurhome.uz' },
    { key: 'address', value: 'Toshkent sh., Chilonzor tumani' },
    { key: 'instagram_url', value: 'https://instagram.com/nuurhome' },
    { key: 'telegram_url', value: 'https://t.me/nuurhome' },
    { key: 'work_hours', value: '09:00 - 18:00' },
    { key: 'about_hero_title', value: 'Biz uyingizga go‘zallik olib kiramiz' },
    { key: 'about_hero_subtitle', value: 'Nuur Home - sifat va nafosat ramzi' }
  ];

  for (const s of defaultSettings) {
    await prisma.siteSetting.upsert({
      where: { key: s.key },
      update: {},
      create: s
    });
  }
  console.log('Seed: Default sozlamalar yaratildi');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

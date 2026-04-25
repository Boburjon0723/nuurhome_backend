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

  console.log('Seed muvaffaqiyatli: Admin yaratildi/yangilandi', admin.email);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

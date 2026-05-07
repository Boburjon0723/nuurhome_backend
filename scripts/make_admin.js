const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function main() {
  const email = 'bs4731450@gmail.com';
  const password = 'admin123';
  const hashedPassword = await bcrypt.hash(password, 10);

  const user = await prisma.user.upsert({
    where: { email: email },
    update: {
      role: 'ADMIN'
    },
    create: {
      email: email,
      password: hashedPassword,
      fullname: 'Admin User',
      role: 'ADMIN'
    }
  });

  console.log(`Muvaffaqiyatli: ${email} foydalanuvchisi ADMIN qilindi.`);
  console.log(`Agar yangi yaratilgan bo'lsa, paroli: ${password}`);
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());

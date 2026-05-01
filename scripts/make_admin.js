const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Terminaldan emailni olish: node scripts/make_admin.js xodim@example.com
const email = process.argv[2];

async function makeAdmin() {
  if (!email) {
    console.log('Iltimos, emailni ko\'rsating: node scripts/make_admin.js email@example.com');
    return;
  }

  try {
    const user = await prisma.user.findUnique({ where: { email } });
    
    if (!user) {
      console.log(`Foydalanuvchi topilmadi: ${email}`);
      return;
    }

    const updatedUser = await prisma.user.update({
      where: { email },
      data: { role: 'ADMIN' }
    });

    console.log(`Muvaffaqiyatli! ${updatedUser.email} endi ADMIN.`);
  } catch (error) {
    console.error('Xatolik:', error);
  } finally {
    await prisma.$disconnect();
  }
}

makeAdmin();

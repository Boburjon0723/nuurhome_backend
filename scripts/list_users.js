const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function listUsers() {
  try {
    const users = await prisma.user.findMany({
      select: {
        email: true,
        fullname: true,
        role: true
      }
    });
    
    if (users.length === 0) {
      console.log('Bazada foydalanuvchilar yo\'q.');
    } else {
      console.log('Mavjud foydalanuvchilar:');
      console.table(users);
    }
  } catch (error) {
    console.error('Xatolik:', error);
  } finally {
    await prisma.$disconnect();
  }
}

listUsers();

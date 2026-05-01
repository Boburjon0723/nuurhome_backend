const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkUsers() {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        fullname: true,
        role: true
      }
    });
    console.log('Foydalanuvchilar ro\'yxati:', JSON.stringify(users, null, 2));
    
    // Enum rollarini tekshirish
    console.log('Tizimdagi rollar (enum):', ['ADMIN', 'CRM', 'ERP', 'SELLER', 'MOBILE_INTAKE', 'USER']);
  } catch (error) {
    console.error('Xatolik:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkUsers();

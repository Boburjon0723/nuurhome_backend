const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    select: {
      email: true,
      fullname: true,
      role: true
    }
  });
  console.log('Users in database:');
  console.table(users);
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());

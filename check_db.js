const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  const count = await prisma.product.count();
  console.log('PRODUCT COUNT:', count);
  const products = await prisma.product.findMany({ take: 1 });
  console.log('SAMPLE:', JSON.stringify(products, null, 2));
}
main().catch(console.error).finally(() => prisma.$disconnect());

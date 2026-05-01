const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Barcha foydalanuvchilarni olish
const getAllUsers = async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        fullname: true,
        role: true,
        phone: true,
        createdAt: true
      },
      orderBy: {
        createdAt: 'desc'
      }
    });
    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Foydalanuvchilarni yuklashda xatolik' });
  }
};

// Foydalanuvchi rolini yangilash
const updateUserRole = async (req, res) => {
  const { id } = req.params;
  const { role } = req.body;

  try {
    const updatedUser = await prisma.user.update({
      where: { id: parseInt(id) || id }, // Handle both int and string IDs if necessary
      data: { role },
      select: {
        id: true,
        email: true,
        fullname: true,
        role: true
      }
    });
    res.json(updatedUser);
  } catch (error) {
    console.error('Error updating user role:', error);
    res.status(500).json({ message: 'Rolni yangilashda xatolik' });
  }
};

// Foydalanuvchini o'chirish
const deleteUser = async (req, res) => {
  const { id } = req.params;

  try {
    await prisma.user.delete({
      where: { id: parseInt(id) || id }
    });
    res.json({ message: 'Foydalanuvchi muvaffaqiyatli o\'chirildi' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ message: 'Foydalanuvchini o\'chirishda xatolik' });
  }
};

module.exports = {
  getAllUsers,
  updateUserRole,
  deleteUser
};

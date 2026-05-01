const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authMiddleware, adminMiddleware } = require('../middleware/authMiddleware');

// Faqat adminlar uchun foydalanuvchilarni boshqarish
router.get('/', authMiddleware, adminMiddleware, userController.getAllUsers);
router.put('/:id/role', authMiddleware, adminMiddleware, userController.updateUserRole);
router.delete('/:id', authMiddleware, adminMiddleware, userController.deleteUser);

module.exports = router;

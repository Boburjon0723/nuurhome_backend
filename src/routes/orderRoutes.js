const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

// All endpoints currently public / not protected by auth middleware for simplicity,
// but you can add authMiddleware here if needed.
router.get('/', orderController.getOrders);
router.get('/trash', orderController.getDeletedOrders);
router.get('/:id', orderController.getOrderById);
router.post('/', orderController.createOrder);
router.put('/:id', orderController.updateOrder);
router.patch('/:id/status', orderController.updateOrderStatus);
router.patch('/:id/restore', orderController.restoreOrder);
router.delete('/:id', orderController.deleteOrder);
router.delete('/:id/permanent', orderController.permanentDeleteOrder);
router.get('/customer/:userId', orderController.getOrdersByUserId);
router.post('/bulk-delete', orderController.deleteOrders);

module.exports = router;

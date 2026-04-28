const express = require('express');
const router = express.Router();
const warehouseController = require('../controllers/warehouseController');

router.get('/inventory', warehouseController.getAllInventory);
router.get('/movements', warehouseController.getStockMovements);
router.post('/add', warehouseController.addStock);
router.post('/bulk-update', warehouseController.bulkUpdateInventory);

module.exports = router;

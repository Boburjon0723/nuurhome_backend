const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');

router.get('/', productController.getAllProducts);
router.get('/by-ids', productController.getProductsByIds);
router.get('/:id', productController.getProductById);
router.post('/', productController.createProduct);
router.put('/:id', productController.updateProduct);
router.post('/bulk-colors', productController.bulkUpdateCategoryColors);
router.delete('/:id', productController.deleteProduct);

module.exports = router;

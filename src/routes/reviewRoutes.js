const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');

router.get('/:productId', reviewController.getProductReviews);
router.post('/', reviewController.addReview);

module.exports = router;

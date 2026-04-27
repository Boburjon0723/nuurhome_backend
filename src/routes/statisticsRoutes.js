const express = require('express');
const router = express.Router();
const statisticsController = require('../controllers/statisticsController');

// All analytics
router.get('/analytics', statisticsController.getAnalytics);

module.exports = router;

const express = require('express');
const router = express.Router();
const albumController = require('../controllers/albumController');

router.get('/', albumController.getAllAlbumImages);
router.post('/', albumController.createAlbumImage);

module.exports = router;

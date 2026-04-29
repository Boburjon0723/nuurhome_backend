const express = require('express');
const router = express.Router();
const albumController = require('../controllers/albumController');

router.get('/', albumController.getAllAlbumImages);
router.post('/', albumController.createAlbumImage);
router.delete('/:id', albumController.deleteAlbumImage);

module.exports = router;

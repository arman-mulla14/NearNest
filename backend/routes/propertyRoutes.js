const express = require('express');
const { getProperties, getPropertyById, createProperty, updateProperty, deleteProperty, addPropertyReview } = require('../controllers/propertyController');
const { protect, vendorOnly } = require('../middlewares/authMiddleware');
const router = express.Router();

router.route('/')
  .get(getProperties)
  .post(protect, vendorOnly, createProperty);

router.route('/:id')
  .get(getPropertyById)
  .put(protect, vendorOnly, updateProperty)
  .delete(protect, vendorOnly, deleteProperty);

router.route('/:id/reviews')
  .post(protect, addPropertyReview);

module.exports = router;

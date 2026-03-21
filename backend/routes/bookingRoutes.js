const express = require('express');
const { createBooking, getVendorBookings, getUserBookings, updateBookingStatus } = require('../controllers/bookingController');
const { protect } = require('../middlewares/authMiddleware');
const router = express.Router();

router.post('/', protect, createBooking);
router.get('/vendor', protect, getVendorBookings);
router.get('/user', protect, getUserBookings);
router.put('/:id/status', protect, updateBookingStatus);

module.exports = router;

const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  property: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  vendor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  status: { type: String, enum: ['pending', 'accepted', 'rejected'], default: 'pending' },
  checkInDate: { type: Date, required: true },
  checkOutDate: { type: Date, required: true },
  totalPrice: { type: Number, required: true }
}, { timestamps: true });

module.exports = mongoose.model('Booking', bookingSchema);

const mongoose = require('mongoose');

const propertySchema = new mongoose.Schema({
  vendor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  description: { type: String, required: true },
  location: { type: String, required: true },
  price: { type: Number, required: true },
  propertyType: { type: String, enum: ['PG', 'Room', 'Lodge', 'Shared Stay', 'Traveling Stay', 'Restaurant'], required: true },
  images: [{ type: String }],
  facilities: [{ type: String }],
  availableBeds: { type: Number, default: 1 },
  availableTables: { type: Number, default: 0 },
  ratings: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    name: { type: String },
    rating: { type: Number, required: true },
    review: { type: String },
    images: [{ type: String }],
    createdAt: { type: Date, default: Date.now }
  }],
}, { timestamps: true });

const Property = mongoose.model('Property', propertySchema);
module.exports = Property;

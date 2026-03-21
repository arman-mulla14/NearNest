const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: { type: String },
  profilePhoto: { type: String },
  dob: { type: Date },
  address: { type: String },
  preferredLocation: { type: String },
  isVerified: { type: Boolean, default: false },
  notificationsEnabled: { type: Boolean, default: true },
  role: { type: String, enum: ['User', 'Vendor', 'Admin'], default: 'User' },
  favorites: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Property' }]
}, { timestamps: true });

userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) {
    next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

userSchema.methods.matchPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

const User = mongoose.model('User', userSchema);
module.exports = User;

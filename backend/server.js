const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const morgan = require('morgan');
const connectDB = require('./config/db');

dotenv.config();
connectDB();

const app = express();

// Middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use(cors());
app.use(morgan('dev'));

// Routes
const authRoutes = require('./routes/authRoutes');
const propertyRoutes = require('./routes/propertyRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const chatRoutes = require('./routes/chatRoutes');
// const adminRoutes = require('./routes/adminRoutes');

app.use('/api/auth', authRoutes);
app.use('/api/properties', propertyRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/chats', chatRoutes);
// app.use('/api/admin', adminRoutes);

app.get('/', (req, res) => {
  res.send('NearNest API is running...');
});

// Settings for production
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
});

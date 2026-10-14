const { Schema } = require('mongoose');

module.exports = new Schema(
    {
        text: { type: String, required: true, trim: true, maxlength: 280 },
        createdAt: { type: Date, default: Date.now },
    },
    { versionKey: false }
);

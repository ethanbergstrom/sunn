var AWS = require('aws-sdk');

AWS.config.update({ region: process.env.SDB_REGION });
sdb = new AWS.SimpleDB();

// Create Promise wrappers
const putAttributes = params => new Promise(
    (resolve,reject) => {
        sdb.putAttributes(params, function(err, data) {
            if (err) reject(err);
            else resolve(data);
        });
    }
);

const select = params => new Promise(
    (resolve,reject) => {
        sdb.select(params, function(err, data) {
            if (err) reject(err);
            else resolve(data);
        });
    }
);

// Export wrappers
exports.putAttributes = async(event) => {
    return await putAttributes(event);
};

exports.select = async(event) => {
    return await select(event);
};
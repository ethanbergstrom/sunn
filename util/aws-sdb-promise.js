var AWS = require('aws-sdk');

AWS.config.update({ region: process.env.SDB_REGION });
sdb = new AWS.SimpleDB();

async function attributeToObjects(pairs) {
    var attributes = {};

    pairs.forEach(function(aPair) {
        if (!attributes[aPair.Name]) {
            attributes[aPair.Name] = aPair.Value;
        }
        attributes[aPair.Name].push(aPair.Value);
    });

    return attributes;
}

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
            else {
                // Convert SDBs attributes into Javascript objects
                var items = [];
                items = data.Items.map(function(anItem) {
                    return attributeToObjects(anItem.Attributes);
                })
                resolve(items);
            }
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
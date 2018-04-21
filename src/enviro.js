var AWS = require('aws-sdk');
var uuidv1 = require('uuid/v1');

const headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Credentials": true
};

AWS.config.update({ region: process.env.SDB_REGION })
sdb = new AWS.SimpleDB();

// Create Promise wrappers
const sdbPutAttributes = params => new Promise(
    (resolve,reject) => {
        sdb.PutAttribues(params, function(err, data) {
            if (err) reject(err);
            else resolve(data);
        })
    }
)
const sdbSelect = params => new Promise(
    (resolve,reject) => {
        sdb.Select(params, function(err, data) {
            if (err) reject(err);
            else resolve(data);
        })
    }
)

// Create handlers
async function handlePut(event) {
    try {
        return {
            statusCode: 200,
            headers: headers,
            body: sdbPutAttributes(
                {
                    DomainName: process.env.SDB_DOMAIN,
                    ItemName: uuidv1(),
                    Attributes: [
                        {
                            Name: 'createdAt',
                            Value: new Date().toISOString()
                        },
                        {
                            Name: 'collectedAt',
                            Value: String(event.collectedAt)
                        },
                        {
                            Name: 'accelerometer',
                            Value: String(event.accelerometer)
                        },
                        {
                            Name: 'lux',
                            Value: String(event.lux)
                        },
                        {
                            Name: 'pressure',
                            Value: String(event.pressure)
                        },
                        {
                            Name: 'rgb',
                            Value: String(event.rgb)
                        }
                    ]
                }
            )
        }
    }
    catch (err) {
        return {
            statusCode: 500,
            headers: headers,
            body: err
        }
    }
}

async function handleGet(event) {

}

// Exports
exports.put = async(event) => {

}

exports.get = async(event) => {

}
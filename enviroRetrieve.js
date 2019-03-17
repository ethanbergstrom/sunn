var sdb = require('aws-sdb-promise');
var headers = require('corsHeaders');

const allowedAttributes = ['temperature','accelerometer','heading','lux','pressure','rgb'];
const maxDaySpan = 31;

// Implement retrieve logic
async function retrieveImpl(event) {
    try {
        if(allowedAttributes.includes(event.attribute) && event.daySpan <= maxDaySpan) {
            console.log('attribute =', event.attribute);
            console.log('lookback =', (new Date(new Date().setDate(new Date().getDate()-event.daySpan)).toISOString()));
            console.log('query =', `SELECT collectedAt, ${event.attribute} FROM ${process.env.SDB_DOMAIN} WHERE collectedAt > '${new Date(new Date().setDate(new Date().getDate()-event.daySpan)).toISOString()}'`);
            return {
                statusCode: 200,
                headers: headers,
                body: await sdb.select(
                    {
                        SelectExpression: `SELECT collectedAt, ${event.attribute} FROM ${process.env.SDB_DOMAIN} WHERE collectedAt > '${new Date(new Date().setDate(new Date().getDate()-event.daySpan)).toISOString()}'`
                    }
                )
            };
        }
    }
    catch(err) {
        console.log(JSON.stringify(err,undefined,2));
        return {
            statusCode: err.statusCode,
            headers: headers,
            body: err
        };
    }
};

// Exports
exports.handler = async(event) => {
    return await retrieveImpl(event);
};
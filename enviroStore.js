var sdb = require('./util/aws-sdb-promise');
var headers = require('./util/corsHeaders');
var uuidv1 = require('uuid/v1');

// Implement store logic
async function storeImpl(event) {
	try {
		return {
			statusCode: 200,
			headers: headers,
			body: await sdb.putAttributes(
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
							Name: 'temperature',
							Value: String(event.temperature)
						},
						{
							Name: 'accelerometer',
							Value: String(event.accelerometer)
						},
						{
							Name: 'heading',
							Value: String(event.heading)
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
	catch(err) {
		console.log(JSON.stringify(err,undefined,2));
		return {
			statusCode: 500,
			headers: headers,
			body: err
		};
	}
};

// Exports
exports.handler = async(event) => {
	return await storeImpl(event);
};
var sdb = require('./util/aws-sdb-promise');
var headers = require('./util/corsHeaders');

const allowedAttributes = ['temperature','accelerometer','heading','lux','pressure','rgb'];
const minuteSpan = 60;
const msPerMinute = 60000;
const timeSpan = minuteSpan * msPerMinute;

// Implement retrieve logic
async function retrieveImpl(event) {
	try {
		const enviroAttributes = event.attributes.filter(value => allowedAttributes.includes(value));
		if (Array.isArray(enviroAttributes) && enviroAttributes.length) {
			console.log('query =', `SELECT collectedAt,${enviroAttributes} FROM \`${process.env.SDB_DOMAIN}\` WHERE collectedAt > '${new Date(new Date() - timeSpan).toISOString()}'`);
			return {
				statusCode: 200,
				headers: headers,
				body: await sdb.select(
					{
						SelectExpression: `SELECT collectedAt,${enviroAttributes} FROM \`${process.env.SDB_DOMAIN}\` WHERE collectedAt > '${new Date(new Date() - timeSpan).toISOString()}'`
					}
				)
			};
		} else {
			throw `Invalid attributes: ${event.attributes}`
		}
	} catch(err) {
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
const fdk = require('@fnproject/fdk');
const NoSQLClient = require('oracle-nosqldb').NoSQLClient;
const client = new NoSQLClient({
	compartment: process.env.COMPARTMENT_OCID,
    auth: {
		iam: {
			useResourcePrincipal: true
		}
	}
});

fdk.handle(async function (input) {
	try {
		return await client.put({
			tableName: process.env.TABLE_NAME,
			row: {
				createdAt: new Date().toISOString(),
				collectedAt: String(input.collectedAt),
				temperature: String(input.temperature),
				lux: String(input.lux),
				pressure: String(input.pressure)
			}
		})
	}

	catch (err) {
		console.log(JSON.stringify(err, undefined, 2));
		return err;
	}
})

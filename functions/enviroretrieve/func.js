const fdk=require('@fnproject/fdk');
const NoSQLClient = require('oracle-nosqldb').NoSQLClient;
const client = new NoSQLClient({
	compartment: process.env.COMPARTMENT_OCID,
    auth: {
		iam: {
			useResourcePrincipal: true
		}
	}
});

const allowedAttributes = ['temperature','lux','pressure'];

fdk.handle(async function (input) { 
	try {
    const enviroAttributes = input.attributes.filter(value => allowedAttributes.includes(value));
    return await client.queryIterable(`SELECT collectedAt,${enviroAttributes} FROM \`${process.env.TABLE_NAME}\` WHERE collectedAt > '${new Date(new Date() - 3600000).toISOString()}'`)
  } catch (err) {
		console.log(JSON.stringify(err, undefined, 2));
		return err;
	}
})

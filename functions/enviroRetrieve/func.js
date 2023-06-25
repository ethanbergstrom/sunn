const fdk=require('@fnproject/fdk');

fdk.handle(function(input){
  let name = "World! (you didnt specify your name, so I'm just returning a generic default.)";
  if (input.name) {
    name = input.name;
  }
  console.log('\nInside Node Hello World function')
  return {'message': 'Hello ' + name}
})

module.exports.handler = async (event) => {
  console.log('EVENT: ', event);
  let message = 'Foo was called!';

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message,
    }),
  }
}

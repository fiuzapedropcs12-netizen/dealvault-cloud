import { CognitoUserPool } from "amazon-cognito-identity-js";

const userPoolId = process.env.NEXT_PUBLIC_COGNITO_USER_POOL_ID;
const clientId = process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID;

if (!userPoolId || !clientId) {
  throw new Error(
    "Faltan NEXT_PUBLIC_COGNITO_USER_POOL_ID o NEXT_PUBLIC_COGNITO_CLIENT_ID",
  );
}

export const userPool = new CognitoUserPool({
  UserPoolId: userPoolId,
  ClientId: clientId,
});

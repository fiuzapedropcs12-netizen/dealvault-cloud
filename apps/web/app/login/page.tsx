"use client";

import { useRef, useState, type FormEvent } from "react";
import {
  AuthenticationDetails,
  CognitoUser,
  CognitoUserAttribute,
  type CognitoUserSession,
} from "amazon-cognito-identity-js";
import { userPool } from "../../lib/cognito";

type Step = "login" | "signup" | "confirm" | "newPassword" | "done";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [code, setCode] = useState("");
  const [step, setStep] = useState<Step>("login");
  const [error, setError] = useState("");
  const [info, setInfo] = useState("");
  const [loggedEmail, setLoggedEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const pendingUser = useRef<CognitoUser | null>(null);

  const goTo = (next: Step) => {
    setError("");
    setInfo("");
    setStep(next);
  };

  const handleSuccess = (session: CognitoUserSession) => {
    setLoggedEmail(session.getIdToken().payload.email as string);
    setStep("done");
    setLoading(false);
  };

  const handleFailure = (err: Error) => {
    setError(err.message);
    setLoading(false);
  };

  const onLogin = (e: FormEvent) => {
    e.preventDefault();
    setError("");
    setInfo("");
    setLoading(true);

    const user = new CognitoUser({ Username: email, Pool: userPool });
    user.authenticateUser(
      new AuthenticationDetails({ Username: email, Password: password }),
      {
        onSuccess: handleSuccess,
        onFailure: (err) => {
          // Se registró pero nunca ingresó el código del mail.
          if (err.name === "UserNotConfirmedException") {
            setLoading(false);
            goTo("confirm");
            setInfo(
              "Tu cuenta todavía no está confirmada. Ingresá el código que te llegó por mail.",
            );
          } else {
            handleFailure(err);
          }
        },
        // Usuarios creados por un admin entran con contraseña temporal
        // y Cognito les exige elegir una nueva en el primer login.
        newPasswordRequired: () => {
          pendingUser.current = user;
          setStep("newPassword");
          setLoading(false);
        },
      },
    );
  };

  const onNewPassword = (e: FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    pendingUser.current?.completeNewPasswordChallenge(
      newPassword,
      {},
      { onSuccess: handleSuccess, onFailure: handleFailure },
    );
  };

  const onSignUp = (e: FormEvent) => {
    e.preventDefault();
    setError("");
    setInfo("");
    setLoading(true);
    userPool.signUp(
      email,
      password,
      [new CognitoUserAttribute({ Name: "email", Value: email })],
      [],
      (err) => {
        setLoading(false);
        if (err) {
          setError(err.message);
          return;
        }
        goTo("confirm");
        setInfo(`Te mandamos un código a ${email}. Revisá también spam.`);
      },
    );
  };

  const onConfirm = (e: FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    const user = new CognitoUser({ Username: email, Pool: userPool });
    user.confirmRegistration(code, true, (err) => {
      setLoading(false);
      if (err) {
        setError(err.message);
        return;
      }
      goTo("login");
      setInfo("Cuenta confirmada. Ya podés iniciar sesión.");
    });
  };

  const onResend = () => {
    setError("");
    const user = new CognitoUser({ Username: email, Pool: userPool });
    user.resendConfirmationCode((err) => {
      if (err) setError(err.message);
      else setInfo("Código reenviado. Revisá tu mail.");
    });
  };

  const onLogout = () => {
    userPool.getCurrentUser()?.signOut();
    setPassword("");
    setNewPassword("");
    goTo("login");
  };

  const input =
    "w-full rounded border border-zinc-300 bg-white px-3 py-2 text-black placeholder:text-zinc-500";
  const button =
    "w-full rounded bg-blue-700 px-3 py-2 font-medium text-white disabled:opacity-50";
  const link = "text-sm text-blue-600 underline dark:text-blue-400";

  return (
    <main className="mx-auto flex min-h-screen max-w-sm flex-col justify-center gap-4 p-6">
      <h1 className="text-2xl font-bold">DealVault</h1>

      {step === "login" && (
        <form onSubmit={onLogin} className="flex flex-col gap-3">
          <input
            className={input}
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <input
            className={input}
            type="password"
            placeholder="Contraseña"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          <button className={button} disabled={loading}>
            {loading ? "Ingresando..." : "Iniciar sesión"}
          </button>
          <button type="button" className={link} onClick={() => goTo("signup")}>
            ¿No tenés cuenta? Crear cuenta
          </button>
        </form>
      )}

      {step === "signup" && (
        <form onSubmit={onSignUp} className="flex flex-col gap-3">
          <input
            className={input}
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <input
            className={input}
            type="password"
            placeholder="Contraseña"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          <p className="text-xs">
            Mínimo 10 caracteres, con mayúscula, minúscula y número.
          </p>
          <button className={button} disabled={loading}>
            {loading ? "Creando..." : "Crear cuenta"}
          </button>
          <button type="button" className={link} onClick={() => goTo("login")}>
            Ya tengo cuenta
          </button>
        </form>
      )}

      {step === "confirm" && (
        <form onSubmit={onConfirm} className="flex flex-col gap-3">
          <input
            className={input}
            type="text"
            inputMode="numeric"
            placeholder="Código de 6 dígitos"
            value={code}
            onChange={(e) => setCode(e.target.value)}
            required
          />
          <button className={button} disabled={loading}>
            {loading ? "Confirmando..." : "Confirmar cuenta"}
          </button>
          <button type="button" className={link} onClick={onResend}>
            Reenviar código
          </button>
        </form>
      )}

      {step === "newPassword" && (
        <form onSubmit={onNewPassword} className="flex flex-col gap-3">
          <p className="text-sm">
            Es tu primer ingreso: elegí una contraseña nueva (mínimo 10
            caracteres, con mayúscula, minúscula y número).
          </p>
          <input
            className={input}
            type="password"
            placeholder="Nueva contraseña"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            required
          />
          <button className={button} disabled={loading}>
            {loading ? "Guardando..." : "Guardar y entrar"}
          </button>
        </form>
      )}

      {step === "done" && (
        <div className="flex flex-col gap-3">
          <p>
            Sesión iniciada como <strong>{loggedEmail}</strong>
          </p>
          <button className={button} onClick={onLogout}>
            Cerrar sesión
          </button>
        </div>
      )}

      {info && <p className="text-sm text-green-600">{info}</p>}
      {error && <p className="text-sm text-red-600">{error}</p>}
    </main>
  );
}

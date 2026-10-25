import { useEffect } from "react";

// Warns the user with the standard "unsaved changes" dialog before leaving the
// page when there are form changes that would be discarded (#106).
export const useUnsavedChangesWarning = (active: boolean) => {
  useEffect(() => {
    if (!active) return;

    const handler = (event: BeforeUnloadEvent) => {
      event.preventDefault();
      // Chrome needs returnValue set, Firefox ignores the custom message
      event.returnValue = "";
    };

    window.addEventListener("beforeunload", handler);
    return () => {
      window.removeEventListener("beforeunload", handler);
    };
  }, [active]);
};
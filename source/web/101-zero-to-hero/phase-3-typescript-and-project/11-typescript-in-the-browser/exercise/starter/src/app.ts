import { heading, type Profile } from "./profile.js";
console.log(heading("Ada"));
async function loadProfile(): Promise<void> {
  const name = document.querySelector("#name");
  const bio = document.querySelector("#bio");
  const skills = document.querySelector("#skills");
  if (!name || !bio || !skills) return;
  try {
    const response = await fetch("./profile.json");
    if (!response.ok) throw new Error("Could not load profile");
    const profile: Profile = await response.json();
    name.textContent = heading(profile.name);
    bio.textContent = profile.bio;
    skills.replaceChildren();
    for (const skill of profile.skills) {
      const item = document.createElement("li");
      item.textContent = skill;
      skills.append(item);
    }
  } catch {
    name.textContent = "Profile unavailable";
    bio.textContent = "Check profile.json, then reload.";
  }
}
if (typeof document !== "undefined") {
  void loadProfile();
}

interface Profile {
  name: string;
  sessions: number;
  active: boolean;
}
function describe(profile: Profile): string {
  if (profile.active) {
    return profile.name + " studies " + profile.sessions + " times a week.";
  }
  return profile.name + " is taking a break.";
}
const profile: Profile = { name: "Ada", sessions: 3, active: true };
console.log(describe(profile));

const learner = "Ada";
let sessions = 1;
sessions = sessions + 1;
const ready = sessions >= 3;
function greeting(name) {
  return "Hello, " + name + "!";
}
console.log(greeting(learner));
if (ready === true) {
  console.log("Ready for practice");
} else {
  console.log("Plan one more session");
}
const topics = ["HTML", "CSS", "JavaScript", "TypeScript"];
for (const topic of topics) {
  console.log("Study: " + topic);
}
console.log("Sessions: " + sessions);

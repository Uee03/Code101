using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("notes")]
public class NotesController(NoteStore store) : ControllerBase
{
    [HttpGet]
    public List<Note> ListNotes() => store.All();

    [HttpGet("{id:int}")]
    public ActionResult<Note> Get(int id)
    {
        Note? note = store.Find(id);
        if (note is null)
        {
            return NotFound();
        }

        return note;
    }

    [HttpPost]
    public ActionResult<Note> Create(CreateNoteRequest request)
    {
        Note created = store.Add(request.Title);
        return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
    }
}

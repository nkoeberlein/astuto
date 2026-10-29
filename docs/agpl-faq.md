# AGPL in companies: FAQ

Astuto Evolution is licensed under the [GNU Affero General Public License v3.0](../LICENSE)
(AGPL-3.0), like the original Astuto. Some legal departments reject the AGPL on principle. This page
explains what it means for the common ways companies run Astuto.

> This is not legal advice. It reflects the usual reading of the license text and of the Free
> Software Foundation's FAQ. If your company has specific concerns, ask your own lawyer.

## Can we use Astuto commercially?

Yes. The AGPL does not restrict who uses the software or for what: internal teams, public feedback
portals for customers and paid services built around it are all allowed. There is no fee and no
registration.

## What do we have to do if we run it unchanged?

Nothing beyond keeping the license and copyright notices. This applies to the Docker image as
published and to a checkout of a release, whether only employees or the whole internet use it.

## What counts as a change?

A change to the program's code: Ruby, TypeScript, templates or translations in this repository,
built into your own image. These are **not** changes to the program:

- configuration via environment variables
- everything in Site settings: branding, custom CSS, header links, webhook templates, OAuth
  providers, languages
- your feedback data: posts, comments, votes, users
- a reverse proxy, a monitoring system or backups around the container

## What if we change the code?

Then section 13 of the AGPL applies: everyone who interacts with your modified version over a
network must be offered the source code of exactly that version, for example through a link in the
footer to a repository or an archive. Employees count as users, so for an internal-only instance it
is enough to give them access (an internal repository is fine). You do not have to publish the code
to the general public, and you do not have to send changes back to this project, although
contributions are welcome.

Changes you only use for development or testing, without others using them, carry no obligation.

## Does the AGPL affect our other software?

Not when it talks to Astuto at arm's length: the REST API (`/api/v1`), webhooks, the MCP server
(`/mcp`), the embedded roadmap or OAuth logins. Programs that only exchange data with Astuto this
way are separate works and keep their own license. The AGPL only reaches code that is combined
with Astuto into one program, for example a patched controller.

## Can we host Astuto for our customers?

Yes. With the unchanged image there is nothing to do. With your own changes, offer their source to
the people using your hosted instances, as described above.

## Is there a commercial license without the AGPL?

Not for v2: it contains code from many contributors of the original project, all under the AGPL,
so nobody can grant a different license for it. A dual license (AGPL plus a commercial license) is
only possible for v3, which is a new implementation, and only with a contributor license agreement
from its first commit (see [roadmap.md](../roadmap.md), sections 6 and 7). The decision so far is
that v3 stays AGPL-3.0.

## Where can we read more?

- [The license text](../LICENSE)
- [FSF: GNU licenses FAQ](https://www.gnu.org/licenses/gpl-faq.html), especially the entries on
  the AGPL and on "aggregate" programs
- [FSF: Why the Affero GPL](https://www.gnu.org/licenses/why-affero-gpl.html)

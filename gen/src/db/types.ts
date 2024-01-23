import { z } from "zod";
const columnSchema = z.discriminatedUnion("kind", [
    z.object({ kind: z.literal("varchar"), size: z.number() }),
    z.object({ kind: z.literal("uuid") }),
    z.object({ kind: z.literal("ulid") }),
    z.object({ kind: z.literal("decimal"), precision: z.number(), decimal: z.number() }),
    z.object({ kind: z.literal("bigint") }),
    z.object({ kind: z.literal("boolean") }),
    z.object({ kind: z.literal("datetime") }),
    z.object({ kind: z.literal("enum"), values: z.array(z.string()) }),
]);

const tableSchema = z.object({
    name: z.string(),
    fields: z.array(z.object({
        name: z.string(),
        pk: z.boolean().default(false).optional(),
        kind: columnSchema
    }))
})
type TableSchema = z.infer<typeof tableSchema>

const relationSchema = z.object({
    src_table: z.string(),
    src_field: z.string(),
    dest_table: z.string(),
    dest_field: z.string(),
    kind: z.union([z.literal("one2one"), z.literal("one2many"), z.literal("many2one")])
})

type RelationSchema = z.infer<typeof relationSchema>

const userTable: TableSchema = {
    name: "user",
    fields: [
        { name: "id", pk: true, kind: { kind: "ulid" } },
        { name: "email", kind: { kind: "varchar", size: 300 } }
    ]
}
const sprintTable: TableSchema = {
    name: "sprint",
    fields: [
        { name: "id", pk: true, kind: { kind: "ulid" } },
        { name: "name", kind: { kind: "varchar", size: 50 } }
    ]
}
const sprintUploadTable: TableSchema = {
    name: "sprint_upload",
    fields: [
        { name: "id", pk: true, kind: { kind: "ulid" } },
        { name: "sprint_name", kind: { kind: "varchar", size: 50 } },
        { name: "sprint_id", kind: { kind: "ulid" } },
    ]
}

const relations: RelationSchema[] = [
    { src_table: "sprint_upload", src_field: "sprint_id", dest_table: "sprint", dest_field: "id", kind: "many2one" }
]



const DbSchema = {
    tables: [userTable, sprintTable, sprintUploadTable],
    relations: relations,
}
console.log(Bun.inspect(DbSchema))
import { z } from "zod";

const columnSchema = z.union([
  z.literal("uuid"),
  z.literal("ulid"),
  z.literal("boolean"),
  z.literal("int"),
  z.literal("bigint"),
  z.literal("datetime"),
  z.tuple([
    z.literal("varchar"),
    z.number() // size
  ]),
  z.tuple([
    z.literal("decimal"),
    z.number(), // precision,
    z.number() // decimal
  ]),
  z.tuple([
    z.literal("enum"),
    z.array(z.string()), // values
  ]),
])

const fieldSchema = z.object({
  name: z.string(),
  note: z.string().default("").optional(),
  pk: z.boolean().default(false).optional(),
  optional: z.boolean().default(false).optional(),
  kind: columnSchema
})
type FieldSchema = z.infer<typeof fieldSchema>

const tableSchema = z.object({
  name: z.string(),
  note: z.string().optional(),
  fields: z.array(fieldSchema)
})
type TableSchema = z.infer<typeof tableSchema>

const relationshipKind = z.union([z.literal("one2one"), z.literal("one2many"), z.literal("many2one")])

type RelationshipKind = z.infer<typeof relationshipKind>
const relationSchema = z.object({
  note: z.string().optional(),
  src_table: z.string(),
  src_field: z.string(),
  dest_table: z.string(),
  dest_field: z.string(),
  kind: relationshipKind,
})

type RelationSchema = z.infer<typeof relationSchema>

const rel = (src: string, dest: string, kind: RelationshipKind, note = "") => {
  const [scr_table, src_field] = src.split(".")
  const [dest_table, dest_field] = dest.split(".")
  return {
    src_table: scr_table,
    src_field: src_field,
    dest_table: dest_table,
    dest_field: dest_field,
    kind: kind,
    note: note
  }
}

////////////////////////////////////// TABLES ///////////////////////////////////////

const timestampFields: FieldSchema[] = [
  { name: "created_at", kind: "datetime" },
  { name: "updated_at", kind: "datetime" },
]

const userTable: TableSchema = {
  name: "user",
  fields: [
    { name: "id", pk: true, kind: "ulid" },
    { name: "email", kind: ["varchar", 300] },
    ...timestampFields
  ]
}
const sprintTable: TableSchema = {
  name: "sprint",
  fields: [
    { name: "id", pk: true, kind: "ulid" },
    { name: "name", kind: ["varchar", 50] },
    ...timestampFields
  ]
}
const sprintUploadTable: TableSchema = {
  name: "sprint_upload",
  fields: [
    { name: "id", pk: true, kind: "ulid" },
    { name: "sprint_name", kind: ["varchar", 50] },
    { name: "sprint_id", kind: "ulid" },
    ...timestampFields
  ]
}

const ecuUnitTable: TableSchema = {
  name: "ecu_unit",
  fields: [
    { name: "id", pk: true, kind: ["varchar", 50] },
    { name: "type", pk: true, kind: ["enum", ["telematic", "powertrain", "other"]] },
    ...timestampFields
  ]
}

const ecuSwBlockTable: TableSchema = {
  name: "ecu_sw_block",
  fields: [
    { name: "id", pk: true, kind: "ulid" },
    { name: "ecu_unit_id", kind: ["varchar", 50] },
    { name: "type", pk: true, kind: ["enum", ["telematic", "powertrain", "other"]] },
    ...timestampFields
  ]
}

const relations: RelationSchema[] = [
  rel("sprint_upload.sprint_id", "sprint.id", "many2one", "sprint can have multiple uploads"),
  rel("ecu_sw_block.ecu_unit_id", "ecu_unit.id", "many2one", "ecu unit have multiple software blocks")
]

const DbSchema = {
  tables: [
    userTable,
    sprintTable,
    ecuUnitTable,
    ecuSwBlockTable,
    sprintUploadTable,
  ],
  relations: relations,
}
console.log(Bun.inspect(DbSchema))
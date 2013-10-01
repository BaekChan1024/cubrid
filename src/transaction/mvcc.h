/*
 * Copyright (C) 2008 Search Solution Corporation. All rights reserved by Search Solution.
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 */

/*
 * mvcc_snapshot.h - Multi-Version Concurency Control system (at Server).
 *
 */
#ifndef _MVCC_SNAPSHOT_H_
#define _MVCC_SNAPSHOT_H_

#ident "$Id$"
#include "thread.h"
#include "storage_common.h"
#include "vacuum.h"

#define MVCC_FLAG_VALID_DELID	OR_MVCC_FLAG_VALID_DELID
#define MVCC_FLAG_ENABLED	OR_MVCC_FLAG_ENABLED

/* MVCC Header Macros */
#define MVCC_GET_INSID(header)   \
  ((header)->mvcc_ins_id)

#define MVCC_SET_INSID(header, mvcc_id)   \
  ((header)->mvcc_ins_id = (mvcc_id))

#define MVCC_GET_DELID(header)   \
  ((header)->mvcc_del_id)

#define MVCC_SET_DELID(header, mvcc_id)   \
  ((header)->mvcc_del_id = (mvcc_id))

#define MVCC_SET_NEXT_VERSION(header, next_oid_version)  \
  ((header)->next_version = *(next_oid_version))

#define MVCC_GET_NEXT_VERSION(header)  \
  ((header)->next_version)

#define MVCC_GET_REPID(header)	\
  ((header)->repid)

#define MVCC_SET_REPID(header, rep_id)	\
  ((header)->repid = (rep_id))

#define MVCC_GET_CHN(header)  \
  ((header)->chn)

#define MVCC_SET_CHN(header, chn_)  \
  ((header)->chn = chn_)

#define MVCC_GET_FLAG(header) \
  ((header)->mvcc_flag)

#define MVCC_SET_FLAG(header, flag) \
  ((header)->mvcc_flag = flag)

#define MVCC_IS_FLAG_SET(rec_header_p, flags) \
  (((rec_header_p)->mvcc_flag & (flags)) == (flags))

#define MVCC_SET_FLAG_BITS(rec_header_p, flag) \
  ((rec_header_p)->mvcc_flag |= flag)

#define MVCC_CLEAR_FLAG_BITS(rec_header_p, flag) \
  ((rec_header_p)->mvcc_flag &= ~flag)

/* MVCC Snapshot Macros */
#define MVCC_SNAPSHOT_GET_LOWEST_ACTIVE_ID(snapshot) \
  ((snapshot)->lowest_active_mvccid)

#define MVCC_SNAPSHOT_GET_HIGHEST_COMMITTED_ID(snapshot) \
  ((snapshot)->highest_completed_mvccid)

/* MVCC Record Macros */

/* Check if record is inserted by current transaction */
#define MVCC_IS_REC_INSERTED_BY_ME(thread_p, rec_header_p)	\
  (logtb_is_current_mvccid (thread_p, (rec_header_p)->mvcc_ins_id))

/* Check if record is deleted by current transaction */
#define MVCC_IS_REC_DELETED_BY_ME(thread_p, rec_header_p)	\
  (logtb_is_current_mvccid (thread_p, (rec_header_p)->mvcc_del_id))

/* Check if record was inserted by the transaction identified by mvcc_id */
#define MVCC_IS_REC_INSERTED_BY(rec_header_p, mvcc_id)	\
  ((rec_header_p)->mvcc_ins_id == mvcc_id)

/* Check if record was deleted by the transaction identified by mvcc_id */
#define MVCC_IS_REC_DELETED_BY(rec_header_p, mvcc_id)	\
  ((rec_header_p)->mvcc_del_id == mvcc_id)

/* Check whether MVCC is disabled for this record */
#define MVCC_IS_DISABLED(rec_header_p)	\
  (((rec_header_p)->mvcc_flag & MVCC_FLAG_ENABLED) == 0)

/* Check if record has a valid chn. This is true when:
 *  1. MVCC is disabled for current record (and in-place update is used).
 *  2. MVCC is inserted by current transaction (checking whether it was
 *     deleted is not necessary. Other transactions cannot delete it, while
 *     current transaction would remove it completely.
 */
#define MVCC_IS_REC_CHN_VALID(thread_p, rec_header_p)	    \
  (MVCC_IS_DISABLED (rec_header_p)			    \
    || MVCC_IS_REC_INSERTED_BY_ME (thread_p, rec_header_p))

typedef struct mvcc_snapshot MVCC_SNAPSHOT;

typedef bool (*MVCC_SNAPSHOT_FUNC) (THREAD_ENTRY * thread_p,
				    MVCC_REC_HEADER * rec_header,
				    MVCC_SNAPSHOT * snapshot);
struct mvcc_snapshot
{
  MVCC_SNAPSHOT_FUNC snapshot_fnc;

  MVCCID lowest_active_mvccid;	/* lowest active id */

  MVCCID highest_completed_mvccid;	/* highest committed id */

  MVCCID *active_ids;		/* active ids */

  unsigned int cnt_active_ids;	/* count active ids */

  MVCCID *active_child_ids;	/* active children */

  unsigned int cnt_active_child_ids;	/* count active child ids */
};

typedef enum mvcc_satisfies_delete_result MVCC_SATISFIES_DELETE_RESULT;
enum mvcc_satisfies_delete_result
{
  DELETE_RECORD_INVISIBLE,	/* invisible - created after scan started */
  DELETE_RECORD_CAN_DELETE,	/* is visible and valid - can be deleted */
  DELETE_RECORD_DELETED,	/* deleted by committed transaction */
  DELETE_RECORD_IN_PROGRESS	/* deleted by other in progress transaction */
};				/* Heap record satisfies delete result */

typedef enum mvcc_satisfies_vacuum_result MVCC_SATISFIES_VACUUM_RESULT;
enum mvcc_satisfies_vacuum_result
{
  VACUUM_RECORD_DEAD,		/* record is dead and can be removed */
  VACUUM_RECORD_ALIVE,		/* record is alive */
  VACUUM_RECORD_RECENTLY_DELETED,	/* delete is in progress or it has
					 * recently been committed and the
					 * record is still visible to active
					 * transactions
					 */
  VACUUM_RECORD_RECENTLY_INSERTED,	/* the inserter is still active or
					 * has recently committed
					 */
};				/* Heap record satisfies vacuum result */

extern bool mvcc_satisfies_snapshot (THREAD_ENTRY * thread_p,
				     MVCC_REC_HEADER * rec_header,
				     MVCC_SNAPSHOT * snapshot);
extern MVCC_SATISFIES_VACUUM_RESULT mvcc_satisfies_vacuum (THREAD_ENTRY *
							   thread_p,
							   MVCC_REC_HEADER *
							   rec_header,
							   MVCCID
							   oldest_mvccid);
extern int mvcc_chain_satisfies_vacuum (THREAD_ENTRY * thread_p,
					PAGE_PTR * page_p, VPID page_vpid,
					PGSLOTID slotid, bool reuse_oid,
					bool vacuum_page_only,
					VACUUM_PAGE_DATA * vacuum_data_p,
					MVCCID oldest_active);
extern MVCC_SATISFIES_DELETE_RESULT mvcc_satisfies_delete (THREAD_ENTRY *
							   thread_p,
							   MVCC_REC_HEADER *
							   rec_header);

extern bool mvcc_satisfies_dirty (THREAD_ENTRY * thread_p,
				  MVCC_REC_HEADER * rec_header,
				  MVCC_SNAPSHOT * snapshot);
extern bool mvcc_id_precedes (MVCCID id1, MVCCID id2);
extern bool mvcc_id_follow_or_equal (MVCCID id1, MVCCID id2);

extern int mvcc_allocate_vacuum_data (THREAD_ENTRY * thread_p,
				      VACUUM_PAGE_DATA * vacuum_data_p,
				      int n_slots);
extern void mvcc_init_vacuum_data (THREAD_ENTRY * thread_p,
				   VACUUM_PAGE_DATA * vacuum_data_p,
				   int n_slots);
extern void mvcc_finalize_vacuum_data (THREAD_ENTRY * thread_p,
				       VACUUM_PAGE_DATA * vacuum_data_p);
#endif /* _MVCC_SNAPSHOT_H_ */

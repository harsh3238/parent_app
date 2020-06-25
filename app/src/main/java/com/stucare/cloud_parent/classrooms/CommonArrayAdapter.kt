package org.flipacademy.mvps.classrooms

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.TextView


class AllClassAdapter(
        private val mContext: Context,
        private val layout: Int
) : ArrayAdapter<ClassItem>(mContext, layout){

    var items = ArrayList<ClassItem>()

    fun addItem(item: ClassItem) {
        this.items.add(item)
        notifyDataSetChanged()
    }

    fun addItems(items: List<ClassItem>) {
        this.items.addAll(items)
        notifyDataSetChanged()
    }

    fun clearItems() {
        this.items.clear()
        notifyDataSetChanged()
    }

    fun updateItem(item: ClassItem,  updateIndex:Int){
        this.items.set(updateIndex, item)
        notifyDataSetChanged()
    }

    override fun getDropDownView(position: Int, convertView: View?, parent: ViewGroup): View {
        var v = convertView

        if (v == null) {
            v = LayoutInflater.from(mContext).inflate(layout, parent, false)
        }
        (v as TextView).text = items[position].className
        return v
    }

    override fun getItem(position: Int): ClassItem? {
        return items[position]
    }

    override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
        var v = convertView

        if (v == null) {
            v = LayoutInflater.from(mContext).inflate(layout, parent, false)
        }
        (v as TextView).text = items[position].className
        return v
    }

    override fun getCount(): Int {
        return items.size
    }
}


class AllSubjectAdapter(
        private val mContext: Context,
        private val layout: Int
) : ArrayAdapter<SubjectItem>(mContext, layout){

    var items = ArrayList<SubjectItem>()

    fun addItem(item: SubjectItem) {
        this.items.add(item)
        notifyDataSetChanged()
    }

    fun addItems(items: List<SubjectItem>) {
        this.items.addAll(items)
        notifyDataSetChanged()
    }

    fun clearItems() {
        this.items.clear()
        notifyDataSetChanged()
    }

    fun updateItem(item: SubjectItem,  updateIndex:Int){
        this.items.set(updateIndex, item)
        notifyDataSetChanged()
    }

    override fun getDropDownView(position: Int, convertView: View?, parent: ViewGroup): View {
        var v = convertView

        if (v == null) {
            v = LayoutInflater.from(mContext).inflate(layout, parent, false)
        }
        (v as TextView).text = items[position].subjectName
        return v
    }

    override fun getItem(position: Int): SubjectItem? {
        return items[position]
    }

    override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
        var v = convertView

        if (v == null) {
            v = LayoutInflater.from(mContext).inflate(layout, parent, false)
        }
        (v as TextView).text = items[position].subjectName
        return v
    }

    override fun getCount(): Int {
        return items.size
    }
}
